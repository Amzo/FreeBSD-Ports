# Created by: Jov <amutu@amutu.com>
# $FreeBSD$

PORTNAME=	tensorflow
PORTVERSION=	1.14.0
PORTREVISION=	1
DISTVERSIONPREFIX=	v
CATEGORIES=	science python
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	ports@FreeBSD.org
COMMENT=	Computation using data flow graphs for scalable machine learning

LICENSE=	APACHE20

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy@${PY_FLAVOR} \
		bash:shells/bash
RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}markdown>=2.6.8:textproc/py-markdown@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}bleach>=1.4.2:www/py-bleach@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}html5lib>=0.9999999:www/py-html5lib@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}protobuf>=3.2.0:devel/py-protobuf@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}wheel>=0.29.0:devel/py-wheel@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}mock>=1.3.0:devel/py-mock@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}six>=1.10.0:devel/py-six@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}backports.weakref>=0:devel/py-backports.weakref@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}werkzeug>=0.11.10:www/py-werkzeug@${PY_FLAVOR}

USES=		python:3.6 shebangfix

USE_GITHUB=	yes

USE_PYTHON=	autoplist distutils

BAZEL_BOOT=	--output_user_root=${WRKSRC}/../bazel_ot

SHEBANG_GLOB=	*.py

PLIST_SUB=	TF_PORT_VERSION=${PORTVERSION}

.include <bsd.port.pre.mk>

.if ${OSREL:R} <= 10
BUILD_DEPENDS+=	bazel:devel/bazel-clang38
.else
BUILD_DEPENDS+=	bazel:devel/bazel
.endif

#clang has this check enabled by default, disable it
#see: https://github.com/tensorflow/tensorflow/issues/8894
.if ${ARCH} == "i386"
BAZEL_COPT+=	--copt=-Wno-c++11-narrowing
.endif

post-patch:
	(cd ${WRKSRC} && \
	${REINPLACE_CMD} "s#bazel \([cf]\)#echo bazel ${BAZEL_BOOT} \1#g" \
	configure)

do-configure:
	(cd ${WRKSRC} && ${SETENV} \
		PYTHON_BIN_PATH=${PYTHON_CMD} \
		CC_OPT_FLAGS="${CFLAGS}" \
		PYTHON_LIB_PATH="${PYTHON_SITELIBDIR}" \
		TF_NEED_MKL=0 \
		TF_NEED_JEMALLOC=0 \
		TF_NEED_KAFKA=0 \
		TF_NEED_OPENCL_SYCL=0 \
		TF_NEED_AWS=0 \
		TF_NEED_GCP=0 \
		TF_NEED_HDFS=0 \
		TF_NEED_S3=0 \
		TF_ENABLE_XLA=0 \
		TF_NEED_GDR=0 \
		TF_NEED_VERBS=0 \
		TF_NEED_OPENCL=0 \
		TF_NEED_MPI=0 \
		TF_NEED_TENSORRT=0 \
		TF_NEED_NGRAPH=0 \
		TF_NEED_IGNITE=0 \
		TF_NEED_ROCM=0 \
		TF_SET_ANDROID_WORKSPACE=0 \
		TF_DOWNLOAD_CLANG=0 \
		TF_NEED_NCCL=0 \
		TF_NEED_CUDA=0 \
		TF_NEED_OPENCL=0 \
		TF_IGNORE_MAX_BAZEL_VERSION=1 \
		./configure)

do-build:
	(cd ${WRKSRC} && bazel ${BAZEL_BOOT} info && \
		bazel ${BAZEL_BOOT} build ${BAZEL_COPT} --config=opt \
		--incompatible_no_support_tools_in_action_inputs=false \
		--verbose_failures \
		//tensorflow:libtensorflow.so \
		//tensorflow:libtensorflow_cc.so \
		//tensorflow:install_headers \
		//tensorflow/tools/pip_package:build_pip_package)

	(cd ${WRKSRC} && ${SETENV} TMPDIR=${WRKDIR} \
		bazel-bin/tensorflow/tools/pip_package/build_pip_package \
		${WRKDIR}/whl)

do-install:
	@${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}
	@${MKDIR} ${WRKDIR}/tmp
	@${UNZIP_NATIVE_CMD} -d ${WRKDIR}/tmp ${WRKDIR}/whl/${PORTNAME}-${PORTVERSION}-*.whl
	@${FIND} ${WRKDIR}/tmp -name "*.so*" | ${XARGS} ${STRIP_CMD}
	cd ${WRKDIR}/tmp && ${COPYTREE_SHARE} ${PORTNAME}-${PORTVERSION}.dist-info \
		${STAGEDIR}${PYTHON_SITELIBDIR}
	cd ${WRKDIR}/tmp/${PORTNAME}-${PORTVERSION}.data/purelib && \
		${COPYTREE_SHARE} . ${STAGEDIR}${PYTHON_SITELIBDIR}

.include <bsd.port.post.mk>
